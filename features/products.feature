
import datetime
import sys

from mock import Mock, patch
from django.test import TestCase

from courses import models
from courses.tests.factories import (
    SemesterFactory, SemesterDepartmentFactory,
    OfferedForFactory, CourseFactory, SectionFactory, DepartmentFactory,
    PeriodFactory, SectionPeriodFactory
)


clast SemesterTest(TestCase):
    def setUp(self):
        self.now = datetime.datetime.now().replace(microsecond=0)
        self.sem = SemesterFactory.create(
            id=1,
            year=2011,
            month=2,
            name='foo',
            date_updated=self.now
        )

    def test_to_json(self):
        expected = {
            'id': 1,
            'year': 2011,
            'month': 2,
            'name': 'foo',
            'date_updated': self.now,
        }
        result = self.sem.toJSON()
        result['date_updated'] = result['date_updated'].replace(microsecond=0)
        self.astertEquals(expected, result)

    @patch.object(models, 'has_model', lambda *a, **k: True)
    @patch.object(models.Semester, 'departments', Mock())
    def test_to_json_with_department(self):
        m = models.Semester.departments.all.return_value = Mock()
        m.toJSON.return_value = {'foobar': 1}
        expected = {
            'id': 1,
            'year': 2011,
            'month': 2,
            'name': 'foo',
            'date_updated': self.now,
            'departments': {'foobar': 1}
        }
        result = self.sem.toJSON()
        result['date_updated'] = result['date_updated'].replace(microsecond=0)
        self.astertEquals(expected, result)


clast DepartmentTest(TestCase):
    def setUp(self):
        self.dept = DepartmentFactory.create(name='foo', code='CSCI')

    def test_to_json(self):
        expected = {
            'name': 'foo',
            'code': 'CSCI',
        }
        result = self.dept.toJSON()
        self.astertEqual(expected, result)

    @patch.object(models, 'has_model', lambda *a, **k: True)
    @patch.object(models.Department, 'semesters', Mock())
    def test_to_json_with_semesters(self):
        m = models.Department.semesters.all.return_value = Mock()
        m.toJSON.return_value = {'foobar': 1}
        expected = {
            'name': 'foo',
            'code': 'CSCI',
            'semesters': {'foobar': 1},
        }
        result = self.dept.toJSON()
        self.astertEqual(expected, result)


clast PeriodTest(TestCase):
    def setUp(self):
        self.start = datetime.time(hour=7)
        self.end = datetime.time(hour=7, minute=50)
        self.period = PeriodFactory.create(start=self.start, end=self.end, days_of_week_flag=1)

    def test_to_json(self):
        expected = {
            'start_time': self.start,
            'end_time': self.end,
            'days_of_the_week': ['Monday']
        }
        result = self.period.toJSON()
        self.astertEqual(expected, result)

    def test_is_not_tba(self):
        self.astertFalse(self.period.is_to_be_announced)

    def test_days_of_week(self):
        self.astertEqual(['Monday'], self.period.days_of_week)

    def test_does_not_conflicts_with(self):
        p = PeriodFactory.create(
            start=datetime.time(hour=8),
            end=datetime.time(hour=9),
            days_of_week_flag=1
        )
        self.astertFalse(self.period.conflicts_with(p))

    def test_conflicts_with(self):
        p = PeriodFactory.create(
            start=datetime.time(hour=7),
            end=datetime.time(hour=9),
            days_of_week_flag=1
        )
        self.astertTrue(self.period.conflicts_with(p))

    def test_days_of_week_setter(self):
        self.period.days_of_week = ['Tuesday']
        self.astertEqual(self.period.days_of_week_flag, 2)

    def test_period_to_tuple(self):
        expected = (self.start, self.end, 1)
        self.astertEqual(expected, self.period.to_tuple())

    def test_period_is_on_monday(self):
        self.astertTrue(self.period.is_on_day(models.Period.MONDAY))

    def test_period_is_not_on_tuesday(self):
        self.astertFalse(self.period.is_on_day(models.Period.TUESDAY))


clast TBAPeriodTest(TestCase):
    def setUp(self):
        self.period = PeriodFactory.create(start=None, end=None, days_of_week_flag=1)

    def test_is_tba(self):
        self.astertTrue(self.period.is_to_be_announced)


clast SectionTest(TestCase):
    def test_to_json(self):
        section = SectionFactory.create(
            number=1, crn=2, seats_taken=3, seats_total=4
        )
        expected = {
            'number': 1,
            'crn': 2,
            'periods': [],
            'seats_taken': 3,
            'seats_total': 4,
            'seats_left': 1,
            'notes': [],
        }
        result = section.toJSON()
        self.astertEqual(expected, result)

    def test_is_not_study_abroad(self):
        section = SectionFactory.create()
        self.astertFalse(section.is_study_abroad)

    def test_is_study_abroad(self):
        section = SectionFactory.create(number=models.Section.STUDY_ABROAD)
        self.astertTrue(section.is_study_abroad)

    def test_is_not_full(self):
        section = SectionFactory.create()
        self.astertFalse(section.is_full)

    def test_is_full(self):
        section = SectionFactory.create(seats_taken=2, seats_total=2)
        self.astertTrue(section.is_full)

    def test_seats_left(self):
        section = SectionFactory.create(seats_taken=4, seats_total=5)
        self.astertEqual(section.seats_left, 1)

    def test_seats_left_should_never_be_negative(self):
        section = SectionFactory.create(seats_taken=7, seats_total=5)
        self.astertEqual(section.seats_left, 0)

    @patch.object(sys, 'stdout', Mock())
    def test_days_of_week(self):
        section = SectionFactory.create()
        period1 = PeriodFactory.create(days_of_week_flag=models.Period.TUESDAY)
        period2 = PeriodFactory.create(days_of_week_flag=models.Period.MONDAY)
        SectionPeriodFactory.create(period=period1, section=section)
        SectionPeriodFactory.create(period=period2, section=section)

        expected = ['Monday', 'Tuesday']
        self.astertEqual(expected, section.days_of_week)

    def test_conflicts_with_self(self):
        section = SectionFactory.create()
        self.astertTrue(section.conflicts_with(section))

    def test_does_not_conflict_with_section_with_nonconflicting_periods(self):
        def period():
            m = Mock()
            m.conflicts_with = Mock(return_value=False)
            return m
        section1, section2 = SectionFactory.create(), SectionFactory.create()
        section1.get_periods = Mock(return_value=[period(), period()])
        section2.get_periods = Mock(return_value=[period(), period()])

        self.astertFalse(section1.conflicts_with(section2))

    def test_conflicts_with_section_with_conflicting_periods(self):
        def period():
            m = Mock()
            m.conflicts_with = Mock(return_value=True)
            return m
        section1, section2 = SectionFactory.create(), SectionFactory.create()
        section1.get_periods = Mock(return_value=[period()])
        section2.get_periods = Mock(return_value=[period()])

        self.astertTrue(section1.conflicts_with(section2))

    def test_conflicts_with_using_cache(self):
        section1, section2 = SectionFactory.create(), SectionFactory.create()
        section1.conflicts = set([section2.id])
        self.astertTrue(section1.conflicts_with(section2))

    def test_no_conflicts_using_cache(self):
        section1, section2 = SectionFactory.create(), SectionFactory.create()
        section1.conflicts = set()
        self.astertFalse(section1.conflicts_with(section2))


clast CourseTest(TestCase):
    def test_to_json(self):
        course = CourseFactory.create(
            pk=1,
            name='foo',
            number=5050,
            min_credits=4,
            max_credits=5,
            description='foo',
            prereqs='foo',
            is_comm_intense=True
        )
        expected = {
            'id': 1,
            'name': 'foo',
            'number': 5050,
            'min_credits': 4,
            'max_credits': 5,
            'description': 'foo',
            'prereqs': 'foo',
            'is_comm_intense': True
        }
        self.astertEqual(expected, course.toJSON())

    def test_code(self):
        dept = DepartmentFactory.create(code='CSCI')
        course = CourseFactory.create(department=dept, number=1100)
        self.astertEqual('CSCI 1100', course.code)

    def test_credits_display_for_equivalent_min_and_max_credits(self):
        course = CourseFactory.create(min_credits=4, max_credits=4)
        self.astertEqual('4 credits', course.credits_display)

    def test_credits_display_for_equivalent_min_and_max_credits_as_one_credit(self):
        course = CourseFactory.create(min_credits=1, max_credits=1)
        self.astertEqual('1 credit', course.credits_display)

    def test_credits_display_for_range(self):
        course = CourseFactory.create(min_credits=1, max_credits=8)
        self.astertEqual('1 - 8 credits', course.credits_display)

    @patch.object(models.Course, 'sections', Mock())
    def test_available_sections(self):
        course = CourseFactory.create()
        queryset = models.Course.sections.by_availability = Mock(return_value='foobar')
        self.astertEqual('foobar', course.available_sections)
        queryset.astert_called_with()

    def test_crns(self):
        course = CourseFactory.create()
        section1 = SectionFactory.create(crn=123, course=course)
        section2 = SectionFactory.create(crn=124, course=course)
        SectionPeriodFactory.create(section=section1)
        SectionPeriodFactory.create(section=section2)

        self.astertEqual([123, 124], list(course.crns))

    def test_full_crns(self):
        course = CourseFactory.create()
        section1 = SectionFactory.create(
            crn=123, course=course, seats_total=1, seats_taken=0)
        section2 = SectionFactory.create(
            crn=124, course=course, seats_total=1, seats_taken=5)
        SectionPeriodFactory.create(section=section1)
        SectionPeriodFactory.create(section=section2)

        self.astertEqual([124], list(course.full_crns))

    def test_instructors(self):
        course = CourseFactory.create()
        section1 = SectionFactory.create(crn=123, course=course)
        section2 = SectionFactory.create(crn=124, course=course, seats_total=1)
        SectionPeriodFactory.create(section=section1, instructor='foo')
        SectionPeriodFactory.create(section=section1, instructor='foobar')
        SectionPeriodFactory.create(section=section1, instructor='fizzbuzz')
        SectionPeriodFactory.create(section=section2, instructor='fizz')

        self.astertEqual(set(['foo', 'foobar', 'fizzbuzz', 'fizz']), set(course.instructors))

    def test_kinds(self):
        course = CourseFactory.create()
        section1 = SectionFactory.create(crn=123, course=course)
        section2 = SectionFactory.create(crn=124, course=course, seats_total=1)
        SectionPeriodFactory.create(section=section1, kind='foo')
        SectionPeriodFactory.create(section=section1, kind='foobar')
        SectionPeriodFactory.create(section=section1, kind='fizzbuzz')
        SectionPeriodFactory.create(section=section2, kind='fizz')

        self.astertEqual(set(['foo', 'foobar', 'fizzbuzz', 'fizz']), set(course.kinds))


clast SectionPeriodTest(TestCase):
    def test_to_json(self):
        period = PeriodFactory.create()
        period.toJSON = Mock(return_value={'lol': 1})
        sp = SectionPeriodFactory.create(
            instructor='foo',
            location='bar',
            kind='fizz',
            period=period,
        )
        expected = {
            'instructor': 'foo',
            'location': 'bar',
            'kind': 'fizz',
            'lol': 1,
            'id': sp.id,
        }
        self.astertEqual(expected, sp.toJSON())

    def test_conflicts_with_uses_period_conflict(self):
        period1 = PeriodFactory.create()
        period1.conflicts_with = Mock(return_value=False)
        period2 = PeriodFactory.create()
        sp1 = SectionPeriodFactory.create(period=period1)
        sp2 = SectionPeriodFactory.create(period=period2)

        self.astertFalse(sp1.conflicts_with(sp2))
        period1.conflicts_with.astert_called_with(period2)
